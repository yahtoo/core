%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IRulesPacks:
  func packExists(pack_id: Uint256) -> (res: felt):
  end
end
