// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IPlayers {
    struct QueuedActionInput {
        Attire attire;
        uint16 actionId;
        uint16 regenerateId; // Food (combat), maybe something for non-combat later
        uint16 choiceId; // Melee/Ranged/Magic (combat), logs, ore (non-combat)
        uint16 rightHandEquipmentTokenId; // Axe/Sword/bow, can be empty
        uint16 leftHandEquipmentTokenId; // Shield, can be empty
        uint24 timespan; // How long to queue the action for
        CombatStyle combatStyle; // specific style of combat,  can also be used
    }

    struct Attire {
        uint16 head;
        uint16 neck;
        uint16 body;
        uint16 arms;
        uint16 legs;
        uint16 feet;
        uint16 ring;
        uint16 reserved1;
    }

    struct CombatStats {
        // From skill points
        int16 melee;
        int16 magic;
        int16 ranged;
        int16 health;
        // These include equipment
        int16 meleeDefence;
        int16 magicDefence;
        int16 rangedDefence;
    }

    struct QueuedAction {
        uint16 actionId;
        uint16 regenerateId; // Food (combat), maybe something for non-combat later
        uint16 choiceId; // Melee/Ranged/Magic (combat), logs, ore (non-combat)
        uint16 rightHandEquipmentTokenId; // Axe/Sword/bow, can be empty
        uint16 leftHandEquipmentTokenId; // Shield, can be empty
        uint24 timespan; // How long to queue the action for
        CombatStyle combatStyle; // specific style of combat,  can also be used
        uint24 prevProcessedTime; // How long the action has been processed for previously
        uint24 prevProcessedXPTime; // How much XP has been gained for this action so far
        uint64 queueId; // id of this queued action
        bool isValid; // If we still have the item, TODO: Not used yet
    }

    enum CombatStyle {
        NONE,
        ATTACK,
        DEFENCE
    }

    enum ActionQueueStatus {
        NONE,
        APPEND,
        KEEP_LAST_IN_PROGRESS
    }

    function startActions(
        uint256 _playerId,
        QueuedActionInput[] calldata _queuedActions,
        ActionQueueStatus _queueStatus
    ) external;
    function getActionQueue(uint256 _playerId) external view returns (QueuedAction[] memory);
}
