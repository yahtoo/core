%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from models.card import CardModel
from models.metadata import Metadata
from models.pack import PackCardModel, get_pack_max_supply

# AccessControl/Ownable

from lib.Ownable_base import (
  Ownable_get_owner,

  Ownable_initializer,
  Ownable_only_owner,
  Ownable_transfer_ownership
)

from lib.roles.AccessControl_base import (
  AccessControl_hasRole,
  AccessControl_rolesCount,
  AccessControl_getRoleMember,

  AccessControl_initializer
)

from lib.roles.minter import (
  Minter_role,

  Minter_initializer,
  Minter_onlyMinter,
  Minter_grant,
  Minter_revoke
)

# Constants

from openzeppelin.utils.constants import TRUE, FALSE

#
# Storage
#

@storage_var
func packs_supply_storage() -> (supply: felt):
end

@storage_var
func packs_cards_per_pack_storage(pack_id: Uint256) -> (cards_per_pack: felt):
end

@storage_var
func packs_max_supply_storage(pack_id: Uint256) -> (max_supply: felt):
end

@storage_var
func packs_card_models_len_storage(pack_id: Uint256) -> (len: felt):
end

@storage_var
func packs_card_models_storage(pack_id: Uint256, index: felt) -> (pack_card_model: PackCardModel):
end

@storage_var
func packs_card_models_quantity_storage(pack_id: Uint256, card_model: CardModel) -> (quantity: felt):
end

@storage_var
func packs_metadata_storage(pack_id: Uint256) -> (metadata: Metadata):
end

@storage_var
func rules_cards_address_storage() -> (rules_cards_address: felt):
end

#
# Constructor
#

func constructor{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(owner: felt, _rules_cards_address: felt):
    rules_cards_address_storage.write(_rules_cards_address)

    Ownable_initializer(owner)
    AccessControl_initializer(owner)
    Minter_initializer(owner)

    return ()
end

#
# Getters
#

@view
func packExists{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(pack_id: Uint256) -> (res: felt):
  let (cards_per_pack) = packs_cards_per_pack_storage.read(pack_id)

  tempvar syscall_ptr = syscall_ptr
  tempvar pedersen_ptr = pedersen_ptr
  tempvar range_check_ptr = range_check_ptr

  if cards_per_pack == 0:
      return (FALSE)
  else:
      return (TRUE)
  end
end

@view
func getPackCardModelQuantity{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(pack_id: Uint256, card_model: CardModel) -> (quantity: felt):
  let (quantity) = packs_card_models_quantity_storage.read(pack_id, card_model)
  return (quantity)
end

@view
func getPackMaxSupply{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(pack_id: Uint256) -> (quantity: felt):
  let (max_supply) = packs_max_supply_storage.read(pack_id)
  return (max_supply)
end

@view
func getPack{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(pack_id: Uint256) -> (cards_per_pack: felt, metadata: Metadata):
  let (cards_per_pack) = packs_cards_per_pack_storage.read(pack_id)
  let (metadata) = packs_metadata_storage.read(pack_id)

  return (cards_per_pack, metadata)
end

# Other contracts

@view
func rulesCards{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }() -> (address: felt):
  let (address) = rules_cards_address_storage.read()
  return (address)
end

#
# Externals
#

@external
func createPack{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(
    cards_per_pack: felt,
    pack_card_models_len: felt,
    pack_card_models: PackCardModel*,
    metadata: Metadata
  ) -> (pack_id: Uint256):
  alloc_locals

  let (pack_max_supply) = get_pack_max_supply(cards_per_pack, pack_card_models_len, pack_card_models)

  let (local supply) = packs_supply_storage.read()
  let pack_id = Uint256(supply + 1, 0)

  packs_cards_per_pack_storage.write(pack_id, cards_per_pack)
  packs_max_supply_storage.write(pack_id, pack_max_supply)
  packs_metadata_storage.write(pack_id, metadata)
  packs_card_models_len_storage.write(pack_id, pack_card_models_len)
  _write_pack_card_models_to_storage(pack_id, pack_card_models_len, pack_card_models)

  packs_supply_storage.write(value=supply + 1)

  return (pack_id)
end

#
# Internals
#

func _write_pack_card_models_to_storage{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(pack_id: Uint256, pack_card_models_len: felt, pack_card_models: PackCardModel*):
  if pack_card_models_len == 0:
    return ()
  end

  let index = pack_card_models_len - 1
  let pack_card_model = pack_card_models[index]

  packs_card_models_quantity_storage.write(pack_id, pack_card_model.card_model, pack_card_model.quantity)
  packs_card_models_storage.write(pack_id, index, pack_card_model)
  _write_pack_card_models_to_storage(pack_id=pack_id, pack_card_models_len=index, pack_card_models=pack_card_models)

  return ()
end

##########################################################################################
# MIGHT BE USEFUL IN A FUTURE VERSION OF CAIRO WHICH SUPPORTS RETURNING ARRAY OF STRUCTS #
##########################################################################################

func _retrieve_pack_card_models_from_storage{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(pack_id: Uint256, pack_card_models: PackCardModel*) -> (pack_card_models_len: felt):
  alloc_locals

  let (local pack_card_models_len) = packs_card_models_len_storage.read(pack_id)
  _retrieve_pack_card_models_from_storage_with_len(pack_id, pack_card_models_len, pack_card_models)

  return (pack_card_models_len)
end

func _retrieve_pack_card_models_from_storage_with_len{
    syscall_ptr: felt*,
    pedersen_ptr: HashBuiltin*,
    range_check_ptr
  }(pack_id: Uint256, pack_card_models_len: felt, pack_card_models: PackCardModel*):
  if pack_card_models_len == 0:
    return ()
  end

  let index = pack_card_models_len - 1

  let (pack_card_model) = packs_card_models_storage.read(pack_id, index)
  assert pack_card_models[index] = pack_card_model
  _retrieve_pack_card_models_from_storage_with_len(pack_id=pack_id, pack_card_models_len=index, pack_card_models=pack_card_models)

  return ()
end
