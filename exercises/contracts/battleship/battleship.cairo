## I AM NOT DONE

%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin, BitwiseBuiltin
from starkware.cairo.common.uint256 import Uint256, uint256_le, uint256_unsigned_div_rem, uint256_sub
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import unsigned_div_rem, assert_le_felt, assert_le
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.hash_state import hash_init, hash_update 
from starkware.cairo.common.bitwise import bitwise_and, bitwise_xor
from starkware.cairo.common.math_cmp import is_not_zero

struct Square:    
    member square_commit: felt
    member square_reveal: felt
    member shot: felt
end

struct Player:    
    member address: felt
    member points: felt
    member revealed: felt
end

struct Game:        
    member player1: Player
    member player2: Player
    member next_player: felt
    member last_move: (felt,felt)
    member winner: felt
end

@storage_var
func grid(game_idx : felt, player : felt, x : felt, y : felt) -> (square : Square):
end

@storage_var
func games(game_idx : felt) -> (game_struct : Game):
end

@storage_var
func game_counter() -> (game_counter : felt):
end

func hash_numb{pedersen_ptr : HashBuiltin*}(numb : felt) -> (hash : felt):

    alloc_locals
    
    let (local array : felt*) = alloc()
    assert array[0] = numb
    assert array[1] = 1
    let (hash_state_ptr) = hash_init()
    let (hash_state_ptr) = hash_update{hash_ptr=pedersen_ptr}(hash_state_ptr, array, 2)   
    tempvar pedersen_ptr :HashBuiltin* = pedersen_ptr       
    return (hash_state_ptr.current_hash)
end


## Provide two addresses
@external
func set_up_game{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(player1 : felt, player2 : felt):
    let curr_game:felt = game_counter.read()
    let playerf = Player(player1,0,0)
    let players = Player(player2,0,0)
    let game = Game(playerf, players, 0, (0,0), 0)
    games.write(curr_game, game)
    game_counter.write(curr_game+1)
    return ()
end

@view 
func check_caller{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(caller : felt, game : Game) -> (valid : felt):
    if caller == game.player1.address:
        return(1)
    end
    if caller == game.player2.address:
        return(1)
    end
    return (0)
end

@view
func check_hit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(square_commit : felt, square_reveal : felt) -> (hit : felt):
    let hash:felt = hash_numb(square_reveal)
    assert hash = square_commit
    let (q,r) = unsigned_div_rem(square_reveal,2)
    if r == 1:
        return (1)
    end
    return (0)
end

@external
func bombard{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, bitwise_ptr: BitwiseBuiltin*}(game_idx : felt, x : felt, y : felt, square_reveal : felt):
    alloc_locals
    let (caller_address) = get_caller_address()
        
    let gm:Game = games.read(game_idx)
    let valid:felt = check_caller(caller_address, gm)
    let isnotFirst:felt = is_not_zero(gm.next_player)
    ## check if it is the first move or not and the move is valid.
    with_attr error_message("Caller should be one of the players and the next player should be valid"):
        assert valid = 1
        
        if isnotFirst == 1:
            assert caller_address = gm.next_player
        end
    end
    ## check the previous move by other person and see if our ship has been dsetroyed if it is not the first move.
    ## first check the validity of the provided square_reveal
    local last_move:(felt,felt) = gm.last_move  
    let square_commit1:Square = grid.read(game_idx, gm.player1.address, last_move[0], last_move[1])
    let square_commit2:Square = grid.read(game_idx, gm.player2.address, last_move[0], last_move[1])
    let computed_commit:felt = hash_numb(square_reveal)
    
    local next_player = gm.player1.address
    let hit:felt = check_hit(computed_commit, square_reveal)
    
    let square:Square = grid.read(game_idx, caller_address, x, y)
    let newsquare: Square = Square(square.square_commit, square.square_reveal, 1)
    
    let caller = gm.player1.address

    if isnotFirst == 1:
        if caller_address == gm.player1.address:  
            
            # check the commit of the previous' player
            
            assert square_commit1.square_commit = computed_commit
            if hit == 1:
                gm.player2.points = gm.player2.points+1
                tempvar syscall_ptr :felt* = syscall_ptr
  
            else:
                tempvar syscall_ptr :felt* = syscall_ptr
               
            end
            next_player = gm.player2.address
            grid.write(game_idx, gm.player1.address, x, y, newsquare)
            tempvar syscall_ptr :felt* = syscall_ptr
            
        else:

            assert square_commit2.square_commit = computed_commit
            if hit == 1:
                gm.player1.points = gm.player1.points+1
                tempvar syscall_ptr :felt* = syscall_ptr
               
            else:
                tempvar syscall_ptr :felt* = syscall_ptr
                
            end
            next_player = gm.player1.address
            grid.write(game_idx, gm.player2.address, x, y, newsquare)
            tempvar syscall_ptr :felt* = syscall_ptr
            
        end
        tempvar syscall_ptr :felt* = syscall_ptr
    
    else:
        if caller_address == gm.player1.address: 
            grid.write(game_idx, gm.player1.address, x, y, newsquare)
            tempvar syscall_ptr :felt* = syscall_ptr
        else:
            grid.write(game_idx, gm.player1.address, x, y, newsquare)
            tempvar syscall_ptr :felt* = syscall_ptr
        end
        tempvar syscall_ptr :felt* = syscall_ptr
    
    end

    
    let game = Game(gm.player1, gm.player2, next_player, (x,y), gm.player1.address)
    games.write(game_idx, game)
    return ()
end



## Check malicious call
@external
func add_squares{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(idx : felt, game_idx : felt, hashes_len : felt, hashes : felt*, player : felt, x: felt, y: felt):
    let curr_game:Game = games.read(game_idx)
    with_attr error_message("Caller should be one of the players"):
        let (caller_address) = get_caller_address()
        let valid:felt = check_caller(caller_address, curr_game)
        assert valid = 1
    end
    load_hashes(idx, game_idx, hashes_len, hashes, player, x, y)
    return ()
end

## loops until array length
func load_hashes{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(idx : felt, game_idx : felt, hashes_len : felt, hashes : felt*, player : felt, x: felt, y: felt):
    if idx == hashes_len+1:
        return ()
    end
    let hsh = hashes[idx]
    let sq = Square(hsh, 0,0)
    grid.write(game_idx, player, x, y, sq)
    if x==4:
        load_hashes(idx+1, game_idx, hashes_len, hashes, player, 0, y+1)
    else:
        load_hashes(idx+1, game_idx, hashes_len, hashes, player, x+1, y)
    end
    return ()
end
