net use \\GIS-AURA-WEB\WebGraf_kort 
robocopy \\aura.dk\Services\DataExchange\oee-argic\export \\GIS-AURA-WEB\WebGraf_kort\Proj\Fiber_syd /is

ping 8.8.8.8

net use /delete \\GIS-AURA-WEB\WebGraf_kort