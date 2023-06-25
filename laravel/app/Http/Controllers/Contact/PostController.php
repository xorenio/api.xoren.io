<?php

namespace App\Http\Controllers\Contact;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

use App\Jobs\Emails\Contact\Confirmation as SendConfirmationEmail;
use App\Jobs\Emails\Contact\Received as SendReceivedEmail;

class PostController extends Controller
{
    public function __invoke(Request $request)
    {
        // get POSTed inputs
        $fields = $request->validate(
            [
            'name' => 'required|string|min:3',
            'email' => 'required|email',
            'phone' => 'nullable',
            'message' => 'required|string|min:3',
            ]
        );

        // Send an email to notify of message
        SendReceivedEmail::dispatch($fields);

        // Send an email to confirm received message
        SendConfirmationEmail::dispatch($fields);


        return response()->json(['success' => true], 201);
    }
}