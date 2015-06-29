<?
require 'lib/SimpleCache.php';
require 'settings.php';

header('Content-Type: application/json');

$cache = new Gilbitron\Util\SimpleCache();
$cache->cache_time = 120;

$query = $_GET['query'];
$endpoint = $_GET['endpoint'];
$key = $endpoint . $query;

if($data = $cache->get_cache($key)){
    header('Age: ' . $cache->get_cache_age($key));
} else {
    header('Age: 0');
    $url = 'http://realtime.mbta.com/developer/api/v2/' . $endpoint . '?' . $query . '&api_key=' . $API_KEY;
    $data = $cache->do_curl($url);
    $cache->set_cache($key, $data);
}
print($data);
?>