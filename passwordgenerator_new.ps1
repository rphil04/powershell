# Define a list of 50 common five-letter words
$dictionary = @(
    "tiger", "grass", "light", "apple", "water", "brick", 
    "stone", "cloud", "shine", "flame", "storm", "pearl", 
    "crisp", "bliss", "grain", "frost", "spark", "piano",
    "poppy", "olive", "beach", "dream", "lemon", "flute",
    "glove", "plumb", "scale", "whale", "brave", "grape",
    "slide", "table", "spear", "spice", "voice", "charm",
    "brand", "flint", "carve", "fresh", "smile", "trust",
    "pouch", "shine", "flora", "sleep", "quiet", "proud",
    "climb", "feast"
)

# Function to generate a password
function Generate-Password {
    param(
        [int]$wordCount = 4  # Default to 4 words
    )

    # Ensure the dictionary has enough words
    if ($dictionary.Count -lt $wordCount) {
        Write-Error "Not enough words in the dictionary to generate the password."
        return
    }

    # Shuffle the array and select the specified number of random words
    $selectedWords = $dictionary | Get-Random -Count $wordCount

    # Join the words with periods to form the final password
    $password = $selectedWords -join '.'

    # Return the generated password
    return $password
}

# Example usage: Generate a password with the default 4 words
$password = Generate-Password

# Output the generated password
Write-Host "Generated Password: $password"
