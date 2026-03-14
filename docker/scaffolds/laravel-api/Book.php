<?php

namespace App\Models;

use ApiPlatform\Metadata\ApiProperty;
use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Delete;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Patch;
use ApiPlatform\Metadata\Post;
use ApiPlatform\Metadata\Put;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

/**
 * Book API Resource.
 *
 * All database columns are auto-discovered by API Platform.
 * Use #[ApiProperty] to control read/write visibility per field:
 *   - readable: true/false → included in GET responses
 *   - writable: true/false → accepted in POST/PUT/PATCH requests
 */
#[ApiResource(
    operations: [
        new GetCollection(),
        new Get(),
        new Post(),
        new Put(),
        new Patch(),
        new Delete(),
    ],
    paginationItemsPerPage: 10,
)]
#[ApiProperty(property: 'id', writable: false)]
#[ApiProperty(property: 'created_at', writable: false)]
#[ApiProperty(property: 'updated_at', writable: false)]
class Book extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'author',
        'isbn',
        'publication_date',
    ];

    protected $casts = [
        'publication_date' => 'date',
    ];
}
