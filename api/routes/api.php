<?php

use App\Http\Controllers\API\IzinDashboardController;
use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\API\UserController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\API\LetterController;
use App\Http\Controllers\API\TemplateController;

Route::get("/user/{id}", [UserController::class, "show_user"]);
Route::get('/test', function () {
    return response()->json(['status' => 'ok']);
});



Route::get('/letters', [LetterController::class, 'index']);
Route::get('/letter-formats', [LetterController::class, 'getAllFormats']);
Route::get('/letters/{id}', [LetterController::class, 'show']);
Route::post('/letters', [LetterController::class, 'store']);
Route::put('/letters/{id}/status', [LetterController::class, 'updateStatus']);
Route::delete('/letters/{id}', [LetterController::class, 'destroy']);

// Laporan Izin
Route::get('/izin-dashboard', IzinDashboardController::class)->middleware(
    "auth:sanctum",
);
Route::get('/izin-list', [IzinDashboardController::class, 'izinList'])->middleware(
    "auth:sanctum",
);
Route::get('/izin-detail/{id}', [IzinDashboardController::class, 'IzinDetail'])
    ->middleware('auth:sanctum'
);
Route::post('/izin-update/{id}', [IzinDashboardController::class, 'updateStatus'])->middleware(
    "auth:sanctum",
);
Route::get('/export-approved-letters', [IzinDashboardController::class, 'exportApprovedLetters'])->middleware(
    "auth:sanctum",
);

// Template Surat
Route::get('/templates', [TemplateController::class, 'index'])->middleware(
    "auth:sanctum",
);
Route::post('/templates', [TemplateController::class, 'store'])->middleware(
    "auth:sanctum",
);
Route::get('/templates/{id}', [TemplateController::class, 'show'])->middleware(
    "auth:sanctum",
);
Route::put('/templates/{id}', [TemplateController::class, 'update'])->middleware(
    "auth:sanctum",
);
Route::delete('/templates/{id}', [TemplateController::class, 'destroy'])->middleware(
    "auth:sanctum",
);




Route::get("/user/{id}", [UserController::class, "show_user"])->middleware(
    "auth:sanctum",
);
Route::get("/users", [UserController::class, "show_users"])->middleware(
    "auth:sanctum",
);

Route::post("/login", [AuthController::class, "login"]);
Route::post("/register", [AuthController::class, "register"])->middleware(
    "auth:sanctum",);
