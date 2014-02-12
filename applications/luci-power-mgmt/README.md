Power management tab
====================

Ticket #3785
------------

Power Management page to control power consumption.
Take broadcom reference software Power Management page as reference.

Default power settings should be as below:

    $ pwrctl show

    Power Management Configuration
    Functional Block Status
    CPU Speed auto
    CPU r4k Wait ENABLED
    DRAM Self-Refresh ENABLED
    Ethernet Auto Power Down ENABLED
    Energy Efficient Ethernet ENABLED
    Adaptive Voltage Scaling ENABLED
    AVS Log Period (sec) 0

TODO
----

 * display additional info from pwrctl show

