
using ClassLibrary1;
using ConsoleDump;
using System;

namespace ConsoleApp1
{
    class Program
    {
        static void Main(string[] args)
        {
            var math = new EmojiMath();
            var avocado = new Emoji
            {
                Name = "avocado",
                Glyph = "🥑",
            };
            var unicorn = new Emoji
            {
                Name = "unicorn",
                Glyph = "🦄"
            };

            var result = math.Add(avocado, unicorn);
            Console.WriteLine(result);
            Console.WriteLine("-----------\n");

            Console.WriteLine($"{result.Name} {result.Glyph}");
            Console.WriteLine("-----------\n");

            result.Dump();

            Console.ReadLine();
        }
    }
}
