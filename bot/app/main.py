"""Aiogram bot entry point with aiohttp server for callbacks."""
import asyncio
import logging

from aiogram import Bot, Dispatcher
from aiogram.client.default import DefaultBotProperties
from aiogram.exceptions import TelegramAPIError
from aiohttp import web

from app.config import settings
from app.handlers import router

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


async def handle_send_message(request: web.Request) -> web.Response:
    """Handle callback from API to send a message to the user."""
    bot: Bot = request.app["bot"]
    try:
        data = await request.json()
        chat_id = data.get("chat_id")
        text = data.get("text")
        
        if not chat_id or not text:
            return web.json_response({"error": "chat_id and text are required"}, status=400)
            
        await bot.send_message(chat_id=chat_id, text=text)
        return web.json_response({"status": "ok"})
    except TelegramAPIError as e:
        logger.error(f"Telegram API error: {e}")
        return web.json_response({"error": str(e)}, status=502)
    except Exception as e:
        logger.error(f"Error processing send message: {e}")
        return web.json_response({"error": "Internal Server Error"}, status=500)


async def main() -> None:
    bot = Bot(token=settings.BOT_TOKEN, default=DefaultBotProperties(parse_mode="HTML"))
    dp = Dispatcher()
    dp.include_router(router)
    
    # Setup aiohttp web server
    app = web.Application()
    app["bot"] = bot
    app.router.add_post("/send", handle_send_message)
    
    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, '0.0.0.0', 8001)
    
    logger.info("Starting aiohttp server on port 8001...")
    await site.start()

    logger.info("Bot started, polling...")
    try:
        await dp.start_polling(bot)
    finally:
        await runner.cleanup()


if __name__ == "__main__":
    asyncio.run(main())
