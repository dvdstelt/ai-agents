Import-Module BurntToast

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add('http://+:9999/')
$listener.Start()
Write-Host 'Claude Code notification listener running on :9999'

while ($listener.IsListening) {
    $ctx = $listener.GetContext()
    $reader = [System.IO.StreamReader]::new($ctx.Request.InputStream)
    $label = $reader.ReadToEnd().Trim()
    $reader.Dispose()
    $ctx.Response.Close()
    $body = if ($label) { $label } else { 'Done!' }
    New-BurntToastNotification -Text 'Claude Code', $body
}
