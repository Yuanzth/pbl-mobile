<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Letter extends Model
{
    protected $fillable = [
        'letter_format_id', 'employee_id', 'title', 'status',
        'request_date', 'effective_start_date', 'effective_end_date',
        'notes', 'approved_by', 'approved_at'
    ];

    protected $casts = [
        'request_date' => 'date',
        'effective_start_date' => 'date',
        'effective_end_date' => 'date',
        'approved_at' => 'datetime',
    ];

    public function format()
    {
        return $this->belongsTo(LetterFormat::class, 'letter_format_id');
    }

    public function employee()
    {
        return $this->belongsTo(Employee::class);
    }

    public function approver()
    {
        return $this->belongsTo(User::class, 'approved_by');
    }
}
