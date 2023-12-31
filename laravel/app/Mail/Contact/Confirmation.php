<?php

namespace App\Mail\Contact;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Address;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class Confirmation extends Mailable
{
    use Queueable, SerializesModels;

    protected $fields;
    protected $email_subject;
    protected $email_reply_to;

    /**
     * Create a new message instance.
     */
    public function __construct(
        Array $fields
    ) {
        $this->fields = $fields;

        $this->email_reply_to = [
            new Address(
                env('MAIL_TO_ADDRESS', 'me@xoren.io'),
                env('MAIL_FROM_NAME', 'XOREN.IO'),
            )
        ];

        $this->email_subject = "XOREN.IO - Message Received";
    }

    /**
     * Get the message envelope.
     */
    public function envelope(): Envelope
    {
        return new Envelope(
            replyTo: $this->email_reply_to,
            subject: $this->email_subject,
        );
    }

    /**
     * Get the message content definition.
     */
    public function content(): Content
    {
        return new Content(
            view: 'emails.contact.confirmed',
            with: $this->fields,
        );
    }
}
