*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.FileSystem
Library           RPA.HTTP
Library           RPA.Archive
Library           Dialogs
Library           RPA.Robocorp.Vault
Library           RPA.core.notebook

*** Tasks ***
All tasks go here
    Remove File    ${CURDIR}${/}Orders/orders.csv
    Build Runtime Directory
    Get Orders file
    ${data}=    Read order file
    Launch RSB website
    Process all orders    ${data}
    Create final zip
    [Teardown]    Close Browser
    Remove File    ${CURDIR}${/}Orders/orders.csv

*** Keywords ***
Launch RSB website
    ${Vault_Data}=    Get Secret    Vault_Test
    Open Available Browser    ${Vault_Data}[URL]
    Maximize Browser Window

Cleanup folders
    [Arguments]    ${folder}
    Remove Directory    ${folder}    True
    Create Directory    ${folder}

Build Runtime Directory
    ${OrdersCSV_folder}=    Does Directory Exist    ${CURDIR}${/}Orders
    ${Orders_folder}=    Does Directory Exist    ${CURDIR}${/}Receipts
    ${robots_folder}=    Does Directory Exist    ${CURDIR}${/}Images
    Run Keyword If    '${OrdersCSV_folder}'=='True'    Cleanup folders    ${CURDIR}${/}Orders    ELSE    Create Directory    ${CURDIR}${/}Orders
    Run Keyword If    '${Orders_folder}'=='True'    Cleanup folders    ${CURDIR}${/}Receipts    ELSE    Create Directory    ${CURDIR}${/}Receipts
    Run Keyword If    '${robots_folder}'=='True'    Cleanup folders    ${CURDIR}${/}Images    ELSE    Create Directory    ${CURDIR}${/}Images

Read order file
    ${data}=    Read Table From Csv    ${CURDIR}${/}Orders/orders.csv    header=True
    Return From Keyword    ${data}

Fill Order Form
    [Arguments]    ${row}
    Wait Until Page Contains Element    //button[@class="btn btn-dark"]
    Click Button    //button[@class="btn btn-dark"]
    Select From List By Value    //select[@name="head"]    ${row}[Head]
    Click Element    //input[@value="${row}[Body]"]
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    //input[@placeholder="Shipping address"]    ${row}[Address]
    Click Button    //button[@id="preview"]
    Wait Until Page Contains Element    //div[@id="robot-preview-image"]
    Sleep    5 seconds
    Click Button    //button[@id="order"]
    Sleep    5 seconds

Close and start Browser prior to another transaction
    Close Browser
    Launch RSB website
    Continue For Loop

Handle Server Error
    FOR    ${i}    IN RANGE    ${100}
        ${alert}=    Is Element Visible    //div[@class="alert alert-danger"]
        Run Keyword If    '${alert}'=='True'    Click Button    //button[@id="order"]
        Exit For Loop If    '${alert}'=='False'
    END
    Run Keyword If    '${alert}'=='True'    Close and start Browser prior to another transaction

Save Order recipt and image in pdf
    [Arguments]    ${row}
    Sleep    5 seconds
    ${reciept_data}=    Get Element Attribute    //div[@id="receipt"]    outerHTML
    Html To Pdf    ${reciept_data}    ${CURDIR}${/}Receipts${/}${row}[Order number].pdf
    Screenshot    //div[@id="robot-preview-image"]    ${CURDIR}${/}Images${/}${row}[Order number].png
    Add Watermark Image To Pdf    ${CURDIR}${/}Images${/}${row}[Order number].png    ${CURDIR}${/}Receipts${/}${row}[Order number].pdf    ${CURDIR}${/}Receipts${/}${row}[Order number].pdf
    Click Button    //button[@id="order-another"]

Process all orders
    [Arguments]    ${data}
    FOR    ${row}    IN    @{data}
        Fill Order Form    ${row}
        Handle Server Error
        Save Order recipt and image in pdf    ${row}
    END

Get Orders file
    ${file_url}=    Get Value From User    Enter Orders.csv URL
    Download    ${file_url}    ${CURDIR}${/}Orders/orders.csv
    Sleep    2 seconds

Create final zip
    Archive Folder With Zip    ${CURDIR}${/}Receipts    ${OUTPUT_DIR}${/}Reciepts.zip
    #Should Contain    container    item
