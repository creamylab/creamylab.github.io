
# optimize_images.ps1
Add-Type -AssemblyName System.Drawing

$imgDir = "d:\Personal\CreamyLabGit\creamylab.github.io\img"
$items = Get-ChildItem -Path $imgDir -Include *.jpg,*.jpeg,*.png -Recurse

foreach ($item in $items) {
    Write-Host "Processing $($item.Name)..."
    
    try {
        $img = [System.Drawing.Image]::FromFile($item.FullName)
        
        # Resize if width > 1600
        if ($img.Width -gt 1600) {
            $newWidth = 1600
            $newHeight = [int]($img.Height * ($newWidth / $img.Width))
            $newImg = new-object System.Drawing.Bitmap $newWidth, $newHeight
            $graph = [System.Drawing.Graphics]::FromImage($newImg)
            $graph.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graph.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $graph.DrawImage($img, 0, 0, $newWidth, $newHeight)
            $img.Dispose()
            $img = $newImg
            Write-Host "  Resized to 1600px width."
        }

        # Compression for JPG
        if ($item.Extension -match "\.jpe?g") {
            $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq "image/jpeg" }
            $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
            $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, 80) # 80% Quality
            
            # Save to temporary file
            $tempFile = "$($item.FullName).tmp"
            $img.Save($tempFile, $codec, $encoderParams)
            $img.Dispose()
            
            # Replace original
            Remove-Item $item.FullName
            Rename-Item $tempFile $item.Name
            Write-Host "  Compressed."
        }
        else {
             # For PNG, just save resized version if it was resized, otherwise just dispose
             # (System.Drawing doesn't have great built-in PNG compression parameters like JPEG quality)
             if ($newImg) {
                $tempFile = "$($item.FullName).tmp"
                $img.Save($tempFile, [System.Drawing.Imaging.ImageFormat]::Png)
                $img.Dispose()
                Remove-Item $item.FullName
                Rename-Item $tempFile $item.Name
                 Write-Host "  Saved resized PNG."
             } else {
                $img.Dispose()
             }
        }
        
    }
    catch {
        Write-Error "Failed to process $($item.Name): $_"
        if ($img) { $img.Dispose() }
    }
}

Write-Host "Optimization Complete!"
