<?php

namespace App\Http\Controllers\API;
use App\Models\Letter;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;

class LetterController extends Controller
{

    public function index(Request $request)
    {
        $query = Letter::with(['employee', 'format']);

        if ($request->status !== null) {
            $query->where('status', $request->status);
        }

        if ($request->employee_id) {
            $query->where('employee_id', $request->employee_id);
        }

        return response()->json($query->orderBy('id', 'desc')->get());
    }

    // =========================
    // SHOW A SINGLE LETTER
    // =========================
    public function show($id)
    {
        $letter = Letter::with(['employee', 'format'])->findOrFail($id);
        return response()->json($letter);
    }

    // =========================
    // EMPLOYEE SUBMITS REQUEST
    // =========================
    public function store(Request $request)
    {
        $validated = $request->validate([
            'letter_format_id' => 'required|exists:letter_formats,id',
            'employee_id'      => 'required|exists:employees,id',
            'title'            => 'required|string|max:255',
            'effective_start_date' => 'required|date',
            'effective_end_date'   => 'required|date|after_or_equal:effective_start_date',
            'notes'            => 'nullable|string',
        ]);

        $validated['status'] = 0; // pending
        $validated['request_date'] = Carbon::now()->toDateString();

        $letter = Letter::create($validated);

        return response()->json($letter, 201);
    }

    // =========================
    // ADMIN UPDATES STATUS
    // =========================
    public function updateStatus(Request $request, $id)
    {
        $validated = $request->validate([
            'status' => 'required|in:0,1,2' // pending / approved / rejected
        ]);

        $letter = Letter::findOrFail($id);

        $letter->status = $validated['status'];
        $letter->approved_by = $request->approved_by ?? null; // admin user id
        $letter->approved_at = Carbon::now();

        $letter->save();

        return response()->json([
            'message' => 'Status updated successfully',
            'data' => $letter
        ]);
    }

    // =========================
    // DELETE LETTER REQUEST
    // =========================
    public function destroy($id)
    {
        $letter = Letter::findOrFail($id);
        $letter->delete();

        return response()->json(['message' => 'Letter deleted']);
    }
}
