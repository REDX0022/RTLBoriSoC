# Outputs only the total line count for all .vhd and .vhdl files

$sum = Get-ChildItem -Recurse -Include *.vhd | 
    Where-Object { -not $_.PSIsContainer } |
    ForEach-Object { (Get-Content $_.FullName | Measure-Object -Line).Lines } |
    Measure-Object -Sum

Write-Output $sum.Sum