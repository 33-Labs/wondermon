-- CreateTable
CREATE TABLE "StripeOrder" (
    "id" SERIAL NOT NULL,
    "sessionId" TEXT NOT NULL,
    "itemType" TEXT NOT NULL,
    "tokenId" INTEGER NOT NULL,
    "recipient" TEXT NOT NULL,
    "checkoutCompleted" BOOLEAN NOT NULL DEFAULT false,
    "checkoutExpired" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "StripeOrder_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "StripeOrder_sessionId_key" ON "StripeOrder"("sessionId");
