<?php

namespace App\Http\Controllers\Contact;

use App\Http\Controllers\Controller;
use App\Jobs\Http\Contact\Database\Save as SaveContactRequestToDatabase;
use App\Jobs\Http\Contact\Emails\Confirmation as SendConfirmationEmail;
use App\Jobs\Http\Contact\Emails\Received as SendReceivedEmail;
use Illuminate\Http\Request;

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
        SaveContactRequestToDatabase::dispatch($fields);

        // Send an email to notify of message
        SendReceivedEmail::dispatch($fields);

        // Send an email to confirm received message
        SendConfirmationEmail::dispatch($fields);

        return response()->json(['success' => true], 201);
    }
}
