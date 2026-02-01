// using System;
// using System.Net.Http;
// using System.Text;
// using System.Threading.Tasks;

// public class ApiTest
// {
//     public static async Task Main(string[] args)
//     {
//         var client = new HttpClient();
//         var url = "http://localhost:5069/api/auth/login";
//         var json = "{\"username\":\"admin@pcm.com\",\"password\":\"123456\"}";
//         var content = new StringContent(json, Encoding.UTF8, "application/json");

//         var response = await client.PostAsync(url, content);
//         var result = await response.Content.ReadAsStringAsync();
//         Console.WriteLine(result);
//     }
// }