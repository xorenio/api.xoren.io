<?php

namespace Tests\Feature;

// use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ContactTest extends TestCase
{

    /**
     * A feature test for testing /contact web endpoint.
     */
    public function testContactEndpoint(): void
    {
        // Arrange: Set up the necessary data for the test
        $postData = [
            'name' => 'John',
            'phone' => '1234567890',
            'email' => 'testing@xoren.io',
            'message' => 'This is a test message',
        ];

        // Act: Send a POST request to the /contact endpoint with the given data
        $response = $this
        ->withoutMiddleware()
        ->post('/contact', $postData);

        // Assert: Perform assertions to verify the expected behavior
        $response->assertStatus(201); // Assuming a successful response status code
    }
}
