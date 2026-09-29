$env:JAVA_HOME = "C:\Users\ABC\AppData\Local\Java\jdk-17"
$env:ANDROID_HOME = "C:\Users\ABC\AppData\Local\Android\Sdk"
$env:PATH = "C:\Users\ABC\AppData\Local\Java\jdk-17\bin;C:\Users\ABC\AppData\Local\Android\Sdk\platform-tools;" + $env:PATH
Write-Host "JAVA_HOME=$env:JAVA_HOME"
Write-Host "ANDROID_HOME=$env:ANDROID_HOME"
& "C:\Users\ABC\flutter\bin\flutter.bat" build apk --debug
