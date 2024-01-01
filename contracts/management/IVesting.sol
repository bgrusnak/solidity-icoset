// SPDX-License-Identifier: Private
pragma solidity ^0.8.20;

import "../structures/KPI.sol"; 

interface IVesting {

    /**
     * @dev Indicates an error when empty token is provided.
     */
    error VestingEmptyToken();

    /**
     * @dev Indicates an error when empty airdrop is provided.
     */
    error VestingEmptyAirdrop();
    /**
     * @dev Indicates an error when unathorized person calls airdrop only function
     * @param account Address who calls
     */
    error VestingUnauthorizedAccount(address account);
    /**
     * @dev Indicates an error when no tokens can be redeemed.
     */
    error VestingEmptyRedeem();
    /**
     * @dev Indicates an error when kpi redefines.
     * @param code KPI code
     */
    error VestingKPIAlreadyDefined(bytes32 code);

    /**
     * @dev Indicates an error when kpi is not defined.
     * @param code KPI code
     */
    error VestingKPINotDefined(bytes32 code);
    /**
     * @dev Indicates an error when kpi amount value is incorrect.
     * @param code KPI code
     * @param amount amount provided
     */
    error VestingIncorrectAmount(bytes32 code, uint16 amount);
    /**
     * @dev Indicates an error when kpi weight value is incorrect.
     * @param code KPI code
     * @param amount weight provided
     */
    error VestingIncorrectWeight(bytes32 code, uint16 amount);
    event Redeem(address indexed account, uint256 amount);
    event Distribute(address indexed account, uint256 amount);
    event KPIAdded(
        bytes32 indexed code,
        uint256 indexed time,
        KPITimeStatus indexed timeStatus,
        uint16 weight
    );
    event KPIModified(
        bytes32 indexed code,
        uint256 indexed time,
        KPITimeStatus indexed timeStatus,
        uint16 weight
    );
    event KPIUpdated(bytes32 indexed code, uint16 amount);

    event KPIRemoved(bytes32 indexed code);

    /// @notice Update token address
    /// @param _token New token address.
    function updateToken(address _token) external;

    /// @notice Update token address
    /// @param _airdrop New token address.
    function updateAirdrop(address _airdrop) external;

    /// @notice Distribute the new vesting amount
    /// @param _to Receiver address.
    /// @param _amount Distributed amount.
    function distribute(address _to, uint256 _amount) external;

    /// @notice Take the current unlocked amount
    function redeem() external returns (uint256);

    /// @notice Set the new KPI
    /// @param _code The KPI id code
    /// @param _time timestamp
    /// @param _timeStatus status of the time
    /// @param _weight weight of the KPI parameter in the total KPI
    function addKPI(
        bytes32 _code,
        uint256 _time,
        KPITimeStatus _timeStatus,
        uint16 _weight
    ) external;

    /// @notice Modify the KPI properties
    /// @param _code The KPI id code
    /// @param _time timestamp
    /// @param _timeStatus status of the time
    /// @param _weight weight of the KPI parameter in the total KPI
    function modifyKPI(
        bytes32 _code,
        uint256 _time,
        KPITimeStatus _timeStatus,
        uint16 _weight
    ) external;

    /// @notice Update the  KPI value
    /// @param _code The KPI id code
    /// @param _amount the current value of KPI
    function updateKPI(bytes32 _code, uint16 _amount) external;

    /// @notice Increase the  KPI value
    /// @param _code The KPI id code
    /// @param _amount the added value of KPI
    function increaseKPI(bytes32 _code, uint16 _amount) external;

    /// @notice Remove the KPI from the list
    /// @param _code The KPI id code
    function removeKPI(bytes32 _code) external;

    /// @notice Get the KPI from the list
    /// @param _code The KPI id code
    function getKPI(bytes32 _code) external view returns (KPI memory);
}
