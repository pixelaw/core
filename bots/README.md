# PixeLAW Bots
NodeJS processes that handle automation to ensure PixeLAW is updated and moving as expected.
For example, let's take the snake app. A user's snake needs to move every tick. To ensure
that the snake moves without the user having to sign movement transactions every tick,
the move transaction is offloaded to a QueueBot. So in the snake example, the subsequent
snake move transactions are called QueueEvents. They are events that will happen in the
future.

Another process also inside this package is the PixelBoardBot. The PixelBoardBot
saves the current state of all the pixels and puts them in the web directory to be
served up by the front end.


