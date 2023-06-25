<?php

namespace App\Mail\Contact;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Address;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class Received extends Mailable
{
    use Queueable, SerializesModels;

    protected $email_subject;
    protected $email_from;
    protected $email_reply_to;

    /**
     * Create a new message instance.
     */
    public function __construct(
        public Array $fields
    ) {
        $this->email_reply_to = [
            new Address(
                $fields['email'],
                $fields['name']
            )
        ];

        $this->email_subject = "XOREN.IO - Enquiry Received";
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
            view: 'emails.contact.received',
            with: $this->fields,
        );
    }
}
