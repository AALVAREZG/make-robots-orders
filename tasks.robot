*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF FILE.
...                 sAVES DE SCREENSHOT OF DE ORDERED ROBOT.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the recipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.FileSystem


*** Variables ***
${TEMP_OUTPUT_DIRECTORY}        ${OUTPUT_DIR}${/}tmp${/}
${RECEIPTS_OUTPUT_DIRECTORY}    ${OUTPUT_DIR}${/}receipts${/}


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot orders website
    ${orders}    Get orders
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Wait Until Keyword Succeeds
        ...    5x
        ...    1 sec
        ...    Fill the form    ${order}
    END
    Create a ZIP file of receipt PDF files
    [Teardown]    Close Browser


*** Keywords ***
Open the robot orders website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    ${csv_orders}    Read table from CSV    orders.csv
    RETURN    ${csv_orders}

Close the annoying modal
    Wait Until Page Contains Element    class:modal-dialog
    Click Button    OK

Fill the form
    [Arguments]    ${order}
    Log    ${order}
    Select From List By Index    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    css:.form-control    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    id:preview
    Click Button    id:order
    Assert complete order
    ${pdf}    Store the receipt as a PDF file    ${order}[Order number]
    Click Button    id:order-another

Assert complete order
    Page Should Contain Element    id:order-completion

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview-image    ${TEMP_OUTPUT_DIRECTORY}${order_number}.png
    RETURN    ${TEMP_OUTPUT_DIRECTORY}${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf_file}
    Open Pdf    ${pdf_file}
    Add Watermark Image To Pdf    ${screenshot}    ${pdf_file}
    Close Pdf    ${pdf_file}

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${order_result_html}    Get Element Attribute    id:order-completion    outerHTML
    Html To Pdf    ${order_result_html}    ${RECEIPTS_OUTPUT_DIRECTORY}${order_number}.pdf
    ${screenshot}    Take a screenshot of the robot    ${order_number}
    Embed the robot screenshot to the receipt PDF file
    ...    ${screenshot}
    ...    ${RECEIPTS_OUTPUT_DIRECTORY}${order_number}.pdf

Create a ZIP file of receipt PDF files
    ${zip_file_name}    Set Variable    ${OUTPUT_DIR}/receiptsPDFs.zip
    Archive Folder With Zip
    ...    ${RECEIPTS_OUTPUT_DIRECTORY}
    ...    ${zip_file_name}
    Remove Directory    ${TEMP_OUTPUT_DIRECTORY}    True
    Remove Directory    ${RECEIPTS_OUTPUT_DIRECTORY}    True
