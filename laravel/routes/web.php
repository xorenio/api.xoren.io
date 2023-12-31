<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Http\Request;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
|
| Here is where you can register web routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "web" middleware group. Make something great!
|
*/

/**
 * @description The home page returning 418 http code
 */
Route::get('/', function (Request $request) {
    return response("", 418)->header('Content-Type', 'text/plain'); // I'm a teapot
});


use App\Http\Controllers\Contact\PostController as PostContact;

/**
 * @description Post request for the contact form
 */
Route::post('/contact', PostContact::class)->middleware('throttle:3,1');;
