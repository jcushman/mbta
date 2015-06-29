<?
require 'lib/SimpleCache.php';
require 'settings.php';

header('Content-Type: application/json');

$cache = new Gilbitron\Util\SimpleCache();
$cache->cache_time = 60;

$query = $_GET['query'];
$endpoint = $_GET['endpoint'];

print($cache->get_data($endpoint . $query, 'http://realtime.mbta.com/developer/api/v2/' . $endpoint . '?' . $query . '&api_key=' . $API_KEY));
?>