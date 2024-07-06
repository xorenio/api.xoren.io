<?php

namespace App\Jobs\Http\Contact\Database;

use App\Models\ContactRequest;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class Save implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    protected $_fields;

    /**
     * Create a new job instance.
     *
     * @return void
     */
    public function __construct($fields)
    {
        $this->_fields = $fields;
    }
    /**
     * Execute the job.
     *
     * @return void
     */
    public function handle()
    {
        ContactRequest::create($this->_fields);
    }
}
