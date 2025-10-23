const https = require('https');

exports.handler = async (event) => {
    const city = event.queryStringParameters?.city || "Pune";
    const apiKey = process.env.WEATHER_API_KEY;
    
    if (!apiKey) {
        return {
            statusCode: 500,
            headers: { 
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            body: JSON.stringify({ error: "Weather API key not configured" })
        };
    }

    const url = `https://api.openweathermap.org/data/2.5/weather?q=${city}&appid=${apiKey}&units=metric`;

    try {
        const response = await new Promise((resolve, reject) => {
            https.get(url, (res) => {
                let data = '';
                res.on('data', chunk => data += chunk);
                res.on('end', () => {
                    try {
                        resolve(JSON.parse(data));
                    } catch (e) {
                        reject(e);
                    }
                });
            }).on('error', (err) => reject(err));
        });

        if (response.cod !== 200) {
            return {
                statusCode: 404,
                headers: { 
                    "Content-Type": "application/json",
                    "Access-Control-Allow-Origin": "*"
                },
                body: JSON.stringify({ error: "City not found" })
            };
        }

        return {
            statusCode: 200,
            headers: { 
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            body: JSON.stringify({
                city: response.name,
                temperature: Math.round(response.main.temp),
                weather: response.weather[0].description,
                humidity: response.main.humidity,
                windSpeed: response.wind?.speed || 0
            })
        };
    } catch (error) {
        return {
            statusCode: 500,
            headers: { 
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            body: JSON.stringify({ error: "Failed to fetch weather data" })
        };
    }
};