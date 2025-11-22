<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CheckClock extends Model
{
    protected $fillable = [
        'employee_id', 'check_clock_type', 'date', 'clock_in', 'clock_out',
        'overtime_start', 'overtime_end', 'latitude', 'longitude', 'accuracy_meters'
    ];

    protected $casts = [
        'date' => 'date',
        'clock_in' => 'datetime:H:i',
        'clock_out' => 'datetime:H:i',
        'check_clock_type' => 'boolean',
    ];

    public function employee(): BelongsTo
    {
        return $this->belongsTo(Employee::class);
    }
}