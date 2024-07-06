<?php

namespace App\Jobs\Http\Contact\Emails;

use App\Mail\Contact\Received as SendReceivedEmail;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Mail;

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
            if (in_array(env('MAIL_MAILER', 'log'), ['log', false, "false"])) {

                \Log::info(
                    "\n --- EMAIL LOGGED ---\nEmails\Contact\Received\n"
                    . "\nEmail Data\n"
                    . json_encode($this->fields)
                    . "\n--- EMAIL LOGGED ---\n"
                );
            } else {

                Mail::to(env('MAIL_TO_ADDRESS', 'me@xoren.io'), env('MAIL_FROM_NAME', 'XOREN.IO'))->send(new SendReceivedEmail($this->fields));
            }

        } catch (Exception $e) {

            \Log::error(
                "\n --- EMAIL LOGGED --- Emails\Contact\Received"
                . "\nEmail Data\n"
                . json_encode($this->fields)
                . "\nFault Message\n"
                . json_encode($e->getMessage())
                . "\n--- EMAIL LOGGED ---\n"
            );
        }
    }
}
