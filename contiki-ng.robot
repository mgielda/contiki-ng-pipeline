*** Settings ***
Suite Setup                   Setup
Suite Teardown                Teardown
Test Setup                    Reset Emulation
Resource                      /opt/renode/tests/renode-keywords.robot

*** Variables ***
${UART}                       sysbus.uart0

*** Keywords ***
Create Machine
    [Arguments]               ${elf}      ${name}     ${id}

    Execute Command           emulation SetGlobalSerialExecution true
    Execute Command           mach clear
    Execute Command           set id ${id}
    Execute Command           $name="${name}"
    Execute Command           $bin=@${CURDIR}/${elf}
    Execute Command           i @scripts/single-node/cc2538.resc
    Execute Command           showAnalyzer ${UART} Antmicro.Renode.Analyzers.LoggingUartAnalyzer
    ${tester}=                Create Terminal Tester    ${UART}    machine=${name}  timeout=120

    [return]                  ${tester}

*** Test Cases ***
Should Start Server
    [Tags]                    cc2538dk  contiki-ng  uart
    Execute Command           logFile @${CURDIR}/artifacts/server.log
    Create Machine            artifacts/udp-server.cc2538dk    cc2538dk-server    1
    Start Emulation
    Wait For Line On Uart     Starting Contiki-NG
    Wait For Line On Uart     TI SmartRF06 + cc2538EM
    Execute Command           Save @${CURDIR}/artifacts/server.save

Should Start Client
    [Tags]                    cc2538dk  contiki-ng  uart
    Execute Command           logFile @${CURDIR}/artifacts/client.log
    Create Machine            artifacts/udp-client.cc2538dk    cc2538dk-client    2
    Start Emulation
    Wait For Line On Uart     Starting Contiki-NG
    Wait For Line On Uart     TI SmartRF06 + cc2538EM
    Wait For Line On Uart     Not reachable yet
    Wait For Line On Uart     Not reachable yet
    Execute Command           Save @${CURDIR}/artifacts/client.save

Should Establish Communication
    [Tags]                    cc2538dk  contiki-ng  uart  RPL  IEEE802.15.4
    Execute Command           logFile @${CURDIR}/artifacts/communicate.log
    Execute Command           emulation CreateWirelessMedium "wireless"
    ${t1}=                    Create Machine            artifacts/udp-server.cc2538dk    cc2538dk-server    1
    Execute Command           connector Connect radio wireless
    ${t2}=                    Create Machine            artifacts/udp-client.cc2538dk    cc2538dk-client    2
    Execute Command           connector Connect radio wireless
    Start Emulation
    Wait For Line On Uart     Sending request 0                                 testerId=${t2}
    Wait For Line On Uart     Received request 'hello 0'                        testerId=${t1}
    Wait For Line On Uart     Sending response                                  testerId=${t1}
    Wait For Line On Uart     Received response 'hello 0'                       testerId=${t2}
    Wait For Line On Uart     Received response 'hello 5'                       testerId=${t2}   timeout=120
    Execute Command           Save @${CURDIR}/artifacts/communicate.save

Should Establish Communication After Getting Out Of Range
    [Tags]                    cc2538dk  contiki-ng  uart  RPL  IEEE802.15.4
    Execute Command           logFile @${CURDIR}/artifacts/range_return.log
    Execute Command           emulation CreateWirelessMedium "wireless"
    ${t1}=                    Create Machine            artifacts/udp-server.cc2538dk    cc2538dk-server    1
    Execute Command           connector Connect radio wireless
    Execute Command           wireless SetPosition radio 0 0 0
    ${t2}=                    Create Machine            artifacts/udp-client.cc2538dk    cc2538dk-client    2
    Execute Command           connector Connect radio wireless
    Execute Command           wireless SetPosition radio 10 0 0
    Start Emulation
    Wait For Line On Uart     Sending request 0                                 testerId=${t2}
    Wait For Line On Uart     Received request 'hello 0'                        testerId=${t1}
    Wait For Line On Uart     Sending response                                  testerId=${t1}
    Wait For Line On Uart     Received response 'hello 0'                       testerId=${t2}
    Execute Command           wireless SetRangeWirelessFunction 9
    Wait For Line On Uart     Not reachable yet                                 testerId=${t2}   timeout=60
    Execute Command           wireless SetRangeWirelessFunction 12

    Wait For Line On Uart     Received response 'hello 4'                       testerId=${t2}   timeout=120
    Execute Command           Save @${CURDIR}/artifacts/range_return.save
