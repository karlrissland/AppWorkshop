using PartsUnlimited.Models;
using System;
using System.Runtime.Caching;
using System.Web.Mvc;
using PartsUnlimited.Utils;
using PartsUnlimited.ViewModels;
using System.Net.Http;
using System.Configuration;
using System.Net.Http.Headers;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace PartsUnlimited.Controllers
{
    public class StoreController : Controller
    {
        public StoreController() { }

        private static async Task<T> GetFromStoreService<T>(string path)
        {
            //specify to use TLS 1.2 as default connection
            System.Net.ServicePointManager.SecurityProtocol = SecurityProtocolType.Tls12 | SecurityProtocolType.Tls11 | SecurityProtocolType.Tls;
            
            using (var client = new HttpClient())
            {
                var baseAddress = ConfigurationManager.AppSettings["StoreServiceBaseAddress"];
                var key = ConfigurationManager.AppSettings["StoreServiceKey"];

                client.DefaultRequestHeaders.Accept.Clear();
                client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

                if (!string.IsNullOrWhiteSpace(key))
                {
                    client.DefaultRequestHeaders.Add("x-functions-key", key);
                }

                var uri = new Uri(baseAddress + path);

                HttpResponseMessage response = await client.GetAsync(uri);
                return await response.Content.ReadAsAsync<T>();
            }
        }

        //
        // GET: /Store/
        public async Task<ActionResult> Index()
        {
            return View(await GetFromStoreService<List<Category>>("categories"));
        }

        //
        // GET: /Store/Browse?genre=Disco
        public async Task<ActionResult> Browse(int categoryId)
        {
            return View(await GetFromStoreService<Category>($"categories/{categoryId}"));
        }

        public async Task<ActionResult> Details(int id)
        {
            var productCacheKey = string.Format("product_{0}", id);
            var product = MemoryCache.Default[productCacheKey] as Product;
            if (product == null)
            {
                product = await GetFromStoreService<Product>($"product/{id}");
                //Remove it from cache if not retrieved in last 10 minutes
                MemoryCache.Default.Add(productCacheKey, product, new CacheItemPolicy { SlidingExpiration = TimeSpan.FromMinutes(10) });
            }

            var viewModel = new ProductViewModel
            {
                Product = product,
                ShowRecommendations = ConfigurationHelpers.GetBool("ShowRecommendations")
            };

            return View(viewModel);
        }
    }
}
