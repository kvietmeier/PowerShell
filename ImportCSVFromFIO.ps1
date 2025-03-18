# Define the path to your CSV files and output Excel file
$csvPath = "C:\Users\karl.vietmeier\repos\scripts\fio\logs"  # Update this to your log file path
#$csvPath = "C:\path\to\logs\*.csv"  # Update this to your log file path
$OutputExcel = "C:\Users\karl.vietmeier\OneDrive - Vast Data\Documents\Projects\VastOnCloud\IOTesting\foobar.xlsx"  # Output Excel file


# Create a new Excel object
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $true
$workbook = $excel.Workbooks.Add()

# Counter for worksheet index
$sheetIndex = 1

# Loop through each CSV file
Get-ChildItem -Path $csvPath | ForEach-Object {
    $csv = $_.FullName

    # Check if the file contains data
    if ((Get-Content -Path $csv).Length -gt 0) {
        Write-Output "Importing $csv into Excel..."

        # Create a new worksheet only when there is valid data
        $sheet = $workbook.Sheets.Add()
        $sheet.Name = $_.BaseName.Substring(0, [Math]::Min(31, $_.BaseName.Length))

        # Import CSV into Excel using QueryTables
        $connection = $sheet.QueryTables.Add("TEXT;" + $csv, $sheet.Cells.Item(1, 1))
        $connection.TextFileCommaDelimiter = $true
        $connection.TextFileConsecutiveDelimiter = $false
        $connection.Refresh()

        $sheetIndex++
    } else {
        Write-Output "Skipping empty file: $csv"
    }
}

# Save and close the workbook
$workbook.SaveAs($outputExcel)
$workbook.Close()
$excel.Quit()

Write-Output "CSV files imported to $outputExcel"
