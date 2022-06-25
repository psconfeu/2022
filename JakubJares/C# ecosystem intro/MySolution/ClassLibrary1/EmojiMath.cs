namespace ClassLibrary1
{
    public class EmojiMath
    {
        public Emoji Add(Emoji left, Emoji right)
        {
            var emoji = new Emoji
            {
                Name = $"{left.Name}+{right.Name}",
                Glyph = left.Glyph + right.Glyph,
            };

            return emoji;
        }
    }
}
