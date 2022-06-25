using ClassLibrary1;
using System;
using Xunit;

namespace TestProject1
{
    public class UnitTest1
    {
        [Fact]
        public void AddingTwoEmojisAddsThemToASingleEmojiObject()
        {
            // -- arrange
            var math = new EmojiMath();
            var avocado = new Emoji { Name = "avocado", Glyph = "🥑", };
            var unicorn = new Emoji { Name = "unicorn", Glyph = "🦄" };

            var expected = new Emoji { Name = "avocado+unicorn", Glyph = "🥑🦄" };

            // -- act
            var actual = math.Add(avocado, unicorn);

            // -- assert 
            Assert.Equal(expected.Name, actual.Name);
            Assert.Equal(expected.Glyph, actual.Glyph);
        }
    }
}
