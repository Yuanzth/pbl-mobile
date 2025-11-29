<?php

use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\Api\EmployeeController;
use App\Http\Controllers\Api\EmployeeProfileController;
use App\Http\Controllers\Api\EmployeeManagementController;
use App\Http\Controllers\Api\PositionController;
use App\Http\Controllers\Api\DepartmentController;
use Illuminate\Support\Facades\Route;

// Auth routes
Route::post("/login", [AuthController::class, "login"]);
Route::post("/register", [AuthController::class, "register"])->middleware("auth:sanctum");

// User routes
Route::get("/user/{id}", [UserController::class, "show_user"]);

// Employee routes (read only)
Route::get('employees', [EmployeeController::class, 'index']);
Route::get('employees/{id}', [EmployeeController::class, 'show']);

// Employee profile routes (for logged-in employee)
Route::middleware('auth:sanctum')->group(function () {
    Route::patch('employee/profile/{id}', [EmployeeProfileController::class, 'update']);
});

// Employee management routes (for admin only)
Route::middleware(['auth:sanctum'])->group(function () {
    // TODO: Add 'admin' middleware
    Route::patch('employee/management/{id}', [EmployeeManagementController::class, 'update']);
});

// Other resources
Route::apiResource('positions', PositionController::class);
Route::apiResource('departments', DepartmentController::class);