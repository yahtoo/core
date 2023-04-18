%lang starknet

from starkware.cairo.common.uint256 import Uint256

from ruleslabs.models.metadata import Metadata
from ruleslabs.models.card import Card

@contract_interface
namespace IRulesCards {
  //
  // Getters
  //

  func getCard(card_id: Uint256) -> (card: Card, metadata: Metadata) {
  }

  func cardExists(card_id: Uint256) -> (res: felt) {
  }

  func productionStoppedForSeasonAndScarcity(season: felt, scarcity: felt) -> (stopped: felt) {
  }

  //
  // Business logic
  //

  func createCard(card: Card, metadata: Metadata) -> (card_id: Uint256) {
  }
}
