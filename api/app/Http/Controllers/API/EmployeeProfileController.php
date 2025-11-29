<?php

namespace App\Http\Controllers\Api;

use App\Helpers\ResponseWrapper;
use App\Http\Controllers\Controller;
use App\Models\Employee;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

class EmployeeProfileController extends Controller
{
    /**
     * Update employee personal information (by employee themselves).
     * Only updates: first_name, last_name, gender, address
     */
    public function update(Request $request, string $id)
    {
        $employee = Employee::find($id);
        
        if (!$employee) {
            return ResponseWrapper::make(
                "Karyawan tidak ditemukan",
                404,
                null,
                null
            );
        }

        // TODO: Add authorization check
        // if ($request->user()->employee->id !== (int)$id) {
        //     return ResponseWrapper::make(
        //         "Anda tidak memiliki akses untuk mengubah data ini",
        //         403,
        //         null,
        //         null
        //     );
        // }

        $validated = $request->validate([
            "first_name" => "sometimes|required|string|max:100",
            "last_name" => "sometimes|required|string|max:100",
            "gender" => "sometimes|required|in:L,P",
            "address" => "sometimes|required|string|max:255",
        ]);

        try {
            DB::beginTransaction();

            $employee->update($validated);

            DB::commit();

            $employee->load(['user', 'position', 'department']);

            return ResponseWrapper::make(
                "Informasi pribadi berhasil diperbarui",
                200,
                ["employee" => $employee],
                null
            );

        } catch (Throwable $e) {
            DB::rollBack();

            Log::error('Employee profile update failed', [
                'employee_id' => $employee->id,
                'error' => $e->getMessage(),
                'trace' => $e->getTraceAsString(),
            ]);

            return ResponseWrapper::make(
                "Gagal memperbarui informasi pribadi",
                500,
                null,
                ["error" => "Internal server error"]
            );
        }
    }
}