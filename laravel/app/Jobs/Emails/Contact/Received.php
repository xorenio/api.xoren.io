<?php

namespace App\Jobs\Emails\Contact;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldBeUnique;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

use Illuminate\Support\Facades\Mail;
use App\Mail\Contact\Received as SendReceivedEmail;

class Received implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $fields;

    /**
     * Create a new job instance.
     *
     * @return void
     */
    public function __construct($fields)
    {
        $this->fields = $fields;
    }
    /**
     * Execute the job.
     *
     * @return void
     */
    public function handle()
    {
        try {
            if (in_array(env('MAIL_MAILER', 'log'), ['log', false, "false"]) ) {

                \Log::error(
                    "\n --- EMAIL LOGGED ---\nEmails\Contact\Received\n"
                    ."\nEmail Data\n"
                    .json_encode($this->fields)
                    ."\n--- EMAIL LOGGED ---\n"
                );
            } else {

                Mail::to($this->fields['email'])->send(new SendReceivedEmail($this->fields));
            }

        } catch (Exception $e) {

            \Log::error(
                "\n --- EMAIL LOGGED --- \nFault Message\n"
                .json_encode($e->getMessage())
                ."\nEmail Data\n"
                .json_encode($this->fields)
                ."\n--- EMAIL LOGGED ---\n"
            );
        }
    }
}
