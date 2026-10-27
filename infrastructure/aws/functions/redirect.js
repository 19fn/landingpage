// Permanently redirects the zone apex to the canonical hostname.
function handler(event) {
  var request = event.request;
  var host = request.headers.host ? request.headers.host.value.toLowerCase() : "";

  if (host !== "${apex_host}") {
    return request;
  }

  var parts = [];
  for (var key in request.querystring) {
    var param = request.querystring[key];
    var values = param.multiValue ? param.multiValue : [param];
    for (var i = 0; i < values.length; i++) {
      parts.push(values[i].value === "" ? key : key + "=" + values[i].value);
    }
  }

  return {
    statusCode: 301,
    statusDescription: "Moved Permanently",
    headers: {
      location: {
        value: "https://${canonical_host}" + request.uri + (parts.length ? "?" + parts.join("&") : ""),
      },
    },
  };
}
