<?php

namespace App\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Delete;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Patch;
use ApiPlatform\Metadata\Post;
use ApiPlatform\Metadata\Put;
use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Serializer\Attribute\Groups;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity]
#[ApiResource(
    normalizationContext: ['groups' => ['book:read']],
    denormalizationContext: ['groups' => ['book:write']],
    operations: [
        new GetCollection(),
        new Get(),
        new Post(),
        new Put(),
        new Patch(),
        new Delete(),
    ],
)]
class Book
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column]
    #[Groups(['book:read'])]
    private ?int $id = null;

    #[ORM\Column(length: 255)]
    #[Groups(['book:read', 'book:write'])]
    #[Assert\NotBlank]
    public string $title = '';

    #[ORM\Column(type: Types::TEXT, nullable: true)]
    #[Groups(['book:read', 'book:write'])]
    public ?string $description = null;

    #[ORM\Column(length: 255)]
    #[Groups(['book:read', 'book:write'])]
    #[Assert\NotBlank]
    public string $author = '';

    #[ORM\Column(length: 13, nullable: true)]
    #[Groups(['book:read', 'book:write'])]
    #[Assert\Isbn]
    public ?string $isbn = null;

    #[ORM\Column(type: Types::DATE_IMMUTABLE, nullable: true)]
    #[Groups(['book:read', 'book:write'])]
    public ?\DateTimeImmutable $publicationDate = null;

    #[ORM\Column(type: Types::DATETIME_IMMUTABLE)]
    #[Groups(['book:read'])]
    private \DateTimeImmutable $createdAt;

    #[ORM\Column(type: Types::DATETIME_IMMUTABLE)]
    #[Groups(['book:read'])]
    private \DateTimeImmutable $updatedAt;

    public function __construct()
    {
        $this->createdAt = new \DateTimeImmutable();
        $this->updatedAt = new \DateTimeImmutable();
    }

    public function getId(): ?int
    {
        return $this->id;
    }

    public function getCreatedAt(): \DateTimeImmutable
    {
        return $this->createdAt;
    }

    public function getUpdatedAt(): \DateTimeImmutable
    {
        return $this->updatedAt;
    }

    #[ORM\PreUpdate]
    public function setUpdatedAtValue(): void
    {
        $this->updatedAt = new \DateTimeImmutable();
    }
}
