// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

enum KPITimeStatus {
    // do not use timestamp
    Ignore,
    // kpi is always zero until the timestamp
    NotBefore,
    // kpi is always 1000 (1) after the timestamp
    AlwaysAfter
}
/*
 * KPI allows calculation of vesting value according the different options and time.
 * All KPI values are calculated in promille (1/1000) and are between 0 & 1000 (1)
 */
struct KPI {
    // the service timestamp for the KPI
    uint256 time;
    // how the timestamp should to be processed
    KPITimeStatus timeStatus;
    // current KPI value
    uint16 current;
    // KPI weight in total KPI
    uint16 weight;
}
