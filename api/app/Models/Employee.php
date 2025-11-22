<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Employee extends Model
{
    protected $fillable = [
        'user_id',
        'first_name',
        'last_name',
        'gender',
        'address',
        'position_id',
        'department_id',
        'employment_status',
    ];

    protected $casts = [
        'employment_status' => 'string',
    ];

    // Relasi
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function position(): BelongsTo
    {
        return $this->belongsTo(Position::class);
    }

    public function department(): BelongsTo
    {
        return $this->belongsTo(Department::class);
    }

    public function checkClocks(): HasMany
    {
        return $this->hasMany(CheckClock::class);
    }

    public function letters(): HasMany
    {
        return $this->hasMany(Letter::class);
    }
}