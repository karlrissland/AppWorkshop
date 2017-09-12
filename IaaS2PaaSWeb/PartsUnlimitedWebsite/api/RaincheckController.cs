using PartsUnlimited.Models;
using PartsUnlimited.Utils;
using System.Collections.Generic;
using System.Threading.Tasks;
using System.Web.Http;
using System.Web.Mvc;

namespace PartsUnlimited.Api
{
    [System.Web.Mvc.RoutePrefix("api/raincheck")]
    public class RaincheckController : ApiController
    {
        private readonly IRaincheckQuery _query;

        public RaincheckController(IRaincheckQuery query)
        {
            _query = query;
        }

        [System.Web.Http.HttpGet, System.Web.Mvc.Route]
        public Task<IEnumerable<Raincheck>> Get()
        {
            return _query.GetAllAsync();
        }

        [System.Web.Http.HttpGet, System.Web.Mvc.Route("{id}")]
        public Task<Raincheck> Get(int id)
        {
            return _query.FindAsync(id); 
        }

        [System.Web.Http.HttpPost, System.Web.Mvc.Route]
        public Task<int> Post([FromBody]Raincheck raincheck)
        {
            return _query.AddAsync(raincheck);
        }
    }
}
