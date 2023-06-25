<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>XOREN.IO - Enquiry Received!</title>
</head>
<body>
    <h1><b>{{ $fields['name'] }}</b> Has reached out!</h1>
    <p>email: {{ $fields['email'] }}</p><br/>
    <p>phone: {{ $fields['phone'] }}</p><br/>
    <p>{{ $fields['message'] }}</p>
</body>
</html>