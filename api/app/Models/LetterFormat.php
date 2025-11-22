<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LetterFormat extends Model
{
    protected $fillable = ['name', 'content'];

    public function letters()
    {
        return $this->hasMany(Letter::class);
    }
}
